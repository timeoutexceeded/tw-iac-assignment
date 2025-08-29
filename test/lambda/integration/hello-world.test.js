const fetch = require("node-fetch");
require("dotenv").config({ path: "infra/.env" });

test("GET / should return Hello World", async () => {
     const url = process.env.API_URL;

     const res = await fetch(url);
     const body = await res.json();
     
     expect(res.status).toBe(200);
     expect(body.message).toBe("Hello, World!");
});