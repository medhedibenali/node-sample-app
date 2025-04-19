import test from "node:test";
import assert from "node:assert/strict";

import { handler } from "../src/handler.js";

test("Handler responds correctly", (_t) => {
    const url = "/";
    const remoteAddress = "127.0.0.1";

    const req = {
        url,
        socket: {
            remoteAddress,
        },
    };
    const res = {
        statusCode: null,
        headers: {},
        body: null,
        setHeader(header, value) {
            this.headers[header] = value;
        },
        end(body) {
            this.body = body;
        },
    };

    handler(req, res);

    const expectedStatusCode = 200;
    const expectedHeaders = {
        "Content-Type": "text/plain",
        "X-Remote-Address": remoteAddress,
    };
    const expectedBody = `Hello from '${url}'!`;

    assert.strictEqual(res.statusCode, expectedStatusCode);
    assert.deepStrictEqual(res.headers, expectedHeaders);
    assert.strictEqual(res.body, expectedBody);
});
