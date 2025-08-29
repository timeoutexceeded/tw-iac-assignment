const { handler } = require("../../../src/lambda/hello-world");

describe("hello-world Lambda", () => {
  it("should return Hello World message", async () => {
    const result = await handler({});
    expect(result.statusCode).toBe(200);

    const body = JSON.parse(result.body);
    expect(body.message).toBe("Hello, World!");
  });
});