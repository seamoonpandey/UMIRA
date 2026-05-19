import promClient from "prom-client";
import { env } from "./env.js";

let registry: promClient.Registry | null = null;

/**
 * Gauge — currently registered user count (updated by admin route / cron)
 */
export let registeredUsers: promClient.Gauge | null = null;

/**
 * Counter — total tasks created since app start
 */
export let tasksCreated: promClient.Counter | null = null;

/**
 * Counter — total focus sessions started
 */
export let focusSessionsStarted: promClient.Counter | null = null;

/**
 * Counter — total focus sessions completed
 */
export let focusSessionsCompleted: promClient.Counter | null = null;

/**
 * Counter — API requests by status code family (2xx, 4xx, 5xx)
 */
export let httpRequestsTotal: promClient.Counter | null = null;

/**
 * Histogram — API request duration in seconds
 */
export let httpRequestDuration: promClient.Histogram | null = null;

/**
 * Initialise the Prometheus registry and register all metrics.
 * Call exactly once during server startup.
 */
export function initMetrics(): void {
  if (registry) return; // already initialised

  registry = new promClient.Registry();
  promClient.collectDefaultMetrics({ register: registry });

  registeredUsers = new promClient.Gauge({
    name: "umira_registered_users",
    help: "Total number of registered user accounts",
    registers: [registry],
  });

  tasksCreated = new promClient.Counter({
    name: "umira_tasks_created_total",
    help: "Total number of tasks created",
    registers: [registry],
  });

  focusSessionsStarted = new promClient.Counter({
    name: "umira_focus_sessions_started_total",
    help: "Total number of focus sessions started",
    registers: [registry],
  });

  focusSessionsCompleted = new promClient.Counter({
    name: "umira_focus_sessions_completed_total",
    help: "Total number of focus sessions completed",
    registers: [registry],
  });

  httpRequestsTotal = new promClient.Counter({
    name: "umira_http_requests_total",
    help: "Total number of HTTP requests",
    labelNames: ["method", "route", "status"],
    registers: [registry],
  });

  httpRequestDuration = new promClient.Histogram({
    name: "umira_http_request_duration_seconds",
    help: "HTTP request duration in seconds",
    labelNames: ["method", "route", "status"],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
    registers: [registry],
  });
}

/**
 * Return the Prometheus registry instance.
 * Returns `null` if metrics are disabled or not yet initialised.
 */
export function getRegistry(): promClient.Registry | null {
  return registry;
}

/**
 * Format the registry as plain-text Prometheus exposition format.
 * Returns an empty string when metrics are disabled.
 */
export async function metricsText(): Promise<string> {
  if (!registry) return "";
  return registry.metrics();
}
