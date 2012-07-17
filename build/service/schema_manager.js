// Generated by CoffeeScript 1.3.3
var JSV, SchemaManager, rigger_schema;

JSV = require("JSV").JSV;

rigger_schema = {
  id: "rigger",
  properties: {
    resource: {
      id: "#resource",
      type: "object",
      properties: {
        url: {
          type: "string",
          format: "uri",
          readonly: true
        }
      }
    }
  }
};

SchemaManager = (function() {

  function SchemaManager(application_schema) {
    this.application_schema = application_schema;
    this.jsv = JSV.createEnvironment("json-schema-draft-03");
    this.register_schema(rigger_schema);
    this.register_schema(this.application_schema);
  }

  SchemaManager.prototype.register_schema = function(schema) {
    return this.jsv.createSchema(schema, false, schema.id);
  };

  SchemaManager.prototype.validate = function(type, data) {
    var schema, schema_url;
    schema_url = "urn:" + this.application_schema.id + "#" + type;
    schema = this.jsv.findSchema(schema_url);
    if (schema) {
      return this.jsv.validate(data, schema, function(error) {
        return console.log(error);
      });
    } else {
      throw "unknown schema type: " + type;
    }
  };

  return SchemaManager;

})();

module.exports = SchemaManager;