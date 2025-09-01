const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();
const s3 = new AWS.S3();

exports.handler = async (event) => {
  try {
    const userId = event.queryStringParameters?.userId;
    if (!userId) {
      return {
        statusCode: 400,
        body: "Missing userId",
      };
    }

    const result = await dynamodb
      .get({
        TableName: process.env.DYNAMO_TABLE,
        Key: { userId },
      })
      .promise();

    const htmlFile = result.Item
      ? "index.html"
      : "error.html";

    const html = await s3
      .getObject({
        Bucket: process.env.HTML_BUCKET,
        Key: htmlFile,
      })
      .promise();

    return {
      statusCode: 200,
      headers: { "Content-Type": "text/html" },
      body: html.Body.toString("utf-8"),
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: "Internal Server Error",
    };
  }
};
