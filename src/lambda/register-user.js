const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  try {
    const userId = event.queryStringParameters?.userId;
    if (!userId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Missing userId" }),
      };
    }

    await dynamodb
      .put({
        TableName: process.env.DYNAMO_TABLE,
        Item: { userId },
      })
      .promise();

    return {
      statusCode: 200,
      body: JSON.stringify({ message: `User ${userId} registered successfully` }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error", error: err.message }),
    };
  }
};
