import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, afterAll, afterEach, beforeAll } from "vitest";
import userEvent from "@testing-library/user-event";
import type { YancySchema } from "../../lib/Yancy/Editor/src/types.d.ts";

import StorageEditor from "../../lib/Yancy/Editor/src/storage-editor.svelte";
import type { UserEvent } from "@testing-library/user-event/dist/cjs/setup/setup.js";
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

const fileData: { [key: string]: File } = {};

const handlers = [
  // Add file to storage
  http.post("/api/storage", async ({ request }) => {
    const data = await request.formData();
    const file = data.get("file") as File;
    fileData[file.name] = file;
    return HttpResponse.json({ ok: true });
  }),

  // List files in storage
  http.get("/api/storage", async ({ request }) => {
    return HttpResponse.json({
      items: ["one", "two", "three"],
      total: 3,
    });
  }),

  // Get file from storage
  http.get<{ id: string }>("/api/storage/:id", async ({ params, request }) => {
    const fileId = params.id;
    return HttpResponse.arrayBuffer(TypedArray.from(fileId), {
      headers: {
        "content-type": "text/plain",
      },
    });
  }),
];
const server = setupServer(...handlers);
beforeAll(() => {
  server.listen({ onUnhandledRequest: "error" });
});
afterEach(() => {
  server.resetHandlers();
});
afterAll(() => {
  server.close();
});

describe("StorageEditor", () => {
  test("Lists files in storage", async () => {
    render(StorageEditor, {
      src: "/api/storage",
    });
    await new Promise((resolve) => setTimeout(resolve, 10));
    expect(screen.getAllByRole("option")).toHaveLength(3);
  });
});
