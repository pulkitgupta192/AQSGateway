import * as core from "@actions/core";
import * as github from "@actions/github";
import OpenAI from "openai";
import { components } from "@octokit/openapi-types";

type PullRequestFile = components["schemas"]["diff-entry"];

interface ReviewResponse {
  score: number;
  summary: string;
  critical: string[];
  major: string[];
  minor: string[];
  suggestions: string[];
}

async function run(): Promise<void> {
  try {
    const githubToken = core.getInput("github_token", { required: true });
    const openaiKey = core.getInput("openai_api_key", { required: true });
    const model = core.getInput("model") || "gpt-4o-mini";
    const minScore = parseFloat(core.getInput("min_score") || "7");

    const octokit = github.getOctokit(githubToken);
    const context = github.context;

    if (context.eventName !== "pull_request") {
      core.info("Not a PR event.");
      return;
    }

    const { owner, repo } = context.repo;
    const prNumber = context.payload.pull_request?.number;
    if (!prNumber) throw new Error("PR number not found");

    const { data } = await octokit.rest.pulls.listFiles({
      owner,
      repo,
      pull_number: prNumber,
      per_page: 100
    });

    const files = data as PullRequestFile[];

    const diff = files
      .filter((f) => f.patch)
      .map((f) => `File: ${f.filename}\n${f.patch}`)
      .join("\n\n");

    if (!diff) {
      core.info("No diff found.");
      return;
    }

    const openai = new OpenAI({ apiKey: openaiKey });

    const response = await openai.chat.completions.create({
      model,
      temperature: 0.2,
      messages: [
        {
          role: "system",
          content: `
You are a senior enterprise software architect.

Review the PR diff and respond STRICTLY in valid JSON:

{
  "score": number (0-10),
  "summary": "short summary",
  "critical": [],
  "major": [],
  "minor": [],
  "suggestions": []
}

Scoring rules:
- 9-10: Excellent production-ready
- 7-8: Good but minor improvements
- 5-6: Needs significant fixes
- <5: Dangerous or poor quality
`
        },
        {
          role: "user",
          content: diff
        }
      ]
    });

    const content = response.choices[0].message.content;

    if (!content) throw new Error("No AI response received");

    const review: ReviewResponse = JSON.parse(content);

    const reviewBody = `
## 🤖 AI Code Review

### Score: **${review.score}/10**

### Summary
${review.summary}

### 🔴 Critical
${review.critical.join("\n") || "None"}

### 🟠 Major
${review.major.join("\n") || "None"}

### 🟡 Minor
${review.minor.join("\n") || "None"}

### 💡 Suggestions
${review.suggestions.join("\n") || "None"}
`;

    await octokit.rest.issues.createComment({
      owner,
      repo,
      issue_number: prNumber,
      body: reviewBody
    });

    if (review.score < minScore) {
      core.setFailed(
        `AI score ${review.score} is below required threshold ${minScore}. PR blocked.`
      );
    } else {
      core.info(`PR passed with score ${review.score}`);
    }

  } catch (err: any) {
    core.setFailed(err.message);
  }
}

run();