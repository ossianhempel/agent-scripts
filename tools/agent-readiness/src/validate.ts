import fs from "fs";
import path from "path";
import Ajv from "ajv";

export interface ValidationResult {
  valid: boolean;
  errors: string[];
}

export function validateReport(report: unknown, schemaPath: string): ValidationResult {
  const schemaRaw = fs.readFileSync(schemaPath, "utf8");
  const schema = JSON.parse(schemaRaw) as object;
  const ajv = new Ajv({ allErrors: true, strict: false });
  const validate = ajv.compile(schema);
  const valid = validate(report);
  const errors = (validate.errors || []).map((error) => {
    const location = error.instancePath || "(root)";
    return `${location} ${error.message ?? "is invalid"}`.trim();
  });
  return { valid: Boolean(valid), errors };
}

export function getDefaultSchemaPath(): string {
  return path.join(__dirname, "..", "schemas", "readiness-report.schema.json");
}
