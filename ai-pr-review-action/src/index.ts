import * as core from "@actions/core";
import * as github from "@actions/github";
import OpenAI from "openai";
import { components } from "@octokit/openapi-types";

type PullRequestFile = components["schemas"]["diff-entry"];

async function run(): Promise<void> {
  try {
    const githubToken = core.getInput("github_token", { required: true });
    const openaiKey = core.getInput("openai_api_key", { required: true });
    const model = core.getInput("model") || "gpt-4o-mini";
    const minScore = parseFloat(core.getInput("min_score") || "7");

    const octokit = github.getOctokit(githubToken);
    const context = github.context;

    if (context.eventName !== "pull_request") {
      core.info("This action only runs on pull_request events.");
      return;
    }

    const { owner, repo } = context.repo;
    const prNumber = context.payload.pull_request?.number;

    if (!prNumber) {
      core.setFailed("Pull request number not found.");
      return;
    }

    core.info(`Fetching files for PR #${prNumber}`);

    const { data } = await octokit.rest.pulls.listFiles({
      owner,
      repo,
      pull_number: prNumber,
      per_page: 100
    });

    const files = data as PullRequestFile[];
    const validFilePaths = files.map((f) => f.filename);

    const diff = files
      .filter((f) => f.patch)
      .map((f) => `File: ${f.filename}\n${f.patch}`)
      .join("\n\n");

    if (!diff) {
      core.info("No diff content to review.");
      return;
    }

    const openai = new OpenAI({ apiKey: openaiKey });

    core.info("Sending diff to OpenAI...");

    const response = await openai.chat.completions.create({
      model,
      temperature: 0.2,
      messages: [
        {
          role: "system",
          content:
            "You are a strict enterprise code reviewer. Return ONLY valid JSON in this format: { \"summary\": string, \"issues\": [{ \"file\": string, \"line\": number, \"severity\": \"critical|major|minor\", \"comment\": string }] }"
        },
        {
          role: "user",
          content: `Review the following diff and reference actual filenames and line numbers:\n\n${diff}`
        }
      ]
    });

    const content = response.choices?.[0]?.message?.content || "";

    let parsed: any;

    try {
      parsed = JSON.parse(content);
    } catch {
      core.setFailed("AI did not return valid JSON.");
      return;
    }

    const summary = parsed.summary ?? "No summary provided.";
    const issues = parsed.issues ?? [];

    // ===============================
    // Deterministic Weighted Scoring
    // ===============================

    let score = 10;

    let criticalCount = 0;
    let majorCount = 0;
    let minorCount = 0;

    for (const issue of issues) {
      const severity = issue.severity?.toLowerCase();

      if (severity === "critical") {
        score -= 3;
        criticalCount++;
      } else if (severity === "major") {
        score -= 2;
        majorCount++;
      } else if (severity === "minor") {
        score -= 1;
        minorCount++;
      }
    }

    score = Math.max(0, score);

    core.info(`Deterministic Score: ${score}/10`);
    core.info(
      `Critical: ${criticalCount}, Major: ${majorCount}, Minor: ${minorCount}`
    );

    // ===============================
    // Inline Review Comments
    // ===============================

    const reviewComments = issues
      .filter(
        (issue: any) =>
          issue.file &&
          validFilePaths.includes(issue.file) &&
          typeof issue.line === "number"
      )
      .map((issue: any) => ({
        path: issue.file,
        line: issue.line,
        side: "RIGHT",
        body: `🔎 **${issue.severity?.toUpperCase() || "ISSUE"}**\n\n${issue.comment}`
      }));

    if (reviewComments.length > 0) {
      await octokit.rest.pulls.createReview({
        owner,
        repo,
        pull_number: prNumber,
        event: score < minScore ? "REQUEST_CHANGES" : "COMMENT",
        comments: reviewComments
      });
    }

    // ===============================
    // Summary Comment
    // ===============================

    await octokit.rest.issues.createComment({
      owner,
      repo,
      issue_number: prNumber,
      body: `## 🤖 AI Code Review Summary

**Score:** ${score}/10  
**Minimum Required:** ${minScore}

### 📊 Issue Breakdown
- 🔴 Critical: ${criticalCount}
- 🟠 Major: ${majorCount}
- 🟡 Minor: ${minorCount}

### 📋 Summary
${summary}
`
    });

    // ===============================
    // Enforce Quality Gate
    // ===============================

    if (score < minScore) {
      core.setFailed(
        `PR score ${score} is below required minimum ${minScore}.`
      );
    } else {
      core.info("PR passed AI quality gate.");
    }

  } catch (error: unknown) {
    if (error instanceof Error) {
      core.setFailed(`Action failed: ${error.message}`);
    } else {
      core.setFailed("Unknown error occurred.");
    }
  }
}

run();