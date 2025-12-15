export interface ErrorResponse {
  error: {
    message: string;
    details?: unknown;
  };
}
