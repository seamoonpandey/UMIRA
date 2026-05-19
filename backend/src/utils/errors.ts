export class HttpError extends Error {
  constructor(public statusCode: number, message: string, public code?: string) {
    super(message);
  }
}

export const notFound = (entity: string) => new HttpError(404, `${entity} not found`, "not_found");
export const forbidden = () => new HttpError(403, "forbidden", "forbidden");
export const badRequest = (msg: string) => new HttpError(400, msg, "bad_request");
export const tooManyRequests = () => new HttpError(429, "rate_limit_exceeded", "rate_limit");
