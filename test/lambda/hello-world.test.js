const fetch = require("node-fetch");
require("dotenv").config();

test("GET /hello should return Hello World", async () => {
     const url = process.env.API_URL + "/hello";

     const res = await fetch(url);
     const data = res.json();
     
     expect(res.status).toBe(200);
     expect(data.message).toBe("Hello, world!");
});