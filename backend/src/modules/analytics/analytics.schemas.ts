import { z } from "zod";

export const TrackEvent = z.object({
  eventName: z.string().min(1).max(80),
  props: z.record(z.union([z.string(), z.number(), z.boolean(), z.null()])).optional(),
});
