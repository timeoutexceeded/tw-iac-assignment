const fs = require("fs");
const { execSync } = require("child_process");

describe("Terraform Infrastructure", () => {
     let tfOutput;

     beforeAll(() => {
          execSync("cd infra && terraform init -input=false", { stdio: "inherit" });
          execSync("cd infra && terraform apply -auto-approve -var-file=\"dev.tfvars\" -input=false", { stdio: "inherit" });
          execSync("cd infra && terraform output -json > ../test/infra/tfOutput.json", { encoding: "utf-8" });
          const fileContent = fs.readFileSync("test/infra/tfOutput.json", "utf8");
          tfOutput = JSON.parse(fileContent);
     });

     afterAll(() => {
          execSync("cd infra && terraform destroy -auto-approve -var-file=\"dev.tfvars\" -input=false", { stdio: "inherit" });
     });

     test("API Gateway URL should be defined", () => {
          expect(tfOutput.api_url).toBeDefined();
          expect(tfOutput.api_url.value).toMatch(/^https:\/\/.*\.amazonaws\.com/);
     });

     test("Lambda function name should match", () => {
          expect(tfOutput.hello_world_function_name).toBeDefined();
          expect(tfOutput.hello_world_function_name.value).toBe("iac-assignment-bhanu-hello-world");
     });

     test(".env file has API_URL", () => {
          const env = fs.readFileSync("infra/.env", "utf8");
          expect(env).toMatch(/^API_URL=https:\/\/.+/);
     });
});