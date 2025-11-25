// skills/regulatory-templates-gate1/schemas/field-extraction.js

const baseFieldSchema = {
  type: "object",
  properties: {
    fields: {
      type: "array",
      items: {
        type: "object",
        properties: {
          fieldName: { type: "string" },
          fieldCode: { type: "string" },
          dataType: { type: "string" },
          format: { type: "string" },
          maxLength: { type: "number" },
          mandatory: { type: "boolean" },
          validationRules: {
            type: "array",
            items: { type: "string" }
          },
          exampleValue: { type: "string" },
          midazMapping: { type: "string" },
          confidence: { type: "number" }
        }
      }
    }
  }
};

const cadoc4010Schema = {
  ...baseFieldSchema,
  properties: {
    ...baseFieldSchema.properties,
    specificFields: {
      type: "object",
      properties: {
        cnpj: { type: "string" },
        dataBase: { type: "string" },
        tipoRegistro: { type: "string" }
      }
    }
  }
};

const cadoc4111Schema = {
  ...baseFieldSchema,
  properties: {
    ...baseFieldSchema.properties,
    specificFields: {
      type: "object",
      properties: {
        contaCosif: { type: "string" },
        saldoDiario: { type: "number" },
        dataMovimento: { type: "string" }
      }
    }
  }
};

function getFieldExtractionSchema(templateName) {
  const schemas = {
    "CADOC 4010": cadoc4010Schema,
    "CADOC 4111": cadoc4111Schema,
    "default": baseFieldSchema
  };

  return schemas[templateName] || schemas.default;
}

module.exports = { getFieldExtractionSchema };