mod JsonUtils {
    use Json.JsonElement
    use Json.JsonElement.{JsonObject, JsonString, JsonArray}

    /// Gets a string field from a JSON object
    pub def getJsonString(obj: Map[String, JsonElement], key: String): Option[String] =
        match Map.get(key, obj) {
            case Some(JsonString(s)) => Some(s)
            case _ => None
        }

    /// Gets an array field from a JSON object
    pub def getJsonArray(obj: Map[String, JsonElement], key: String): Option[List[JsonElement]] =
        match Map.get(key, obj) {
            case Some(JsonArray(a)) => Some(a)
            case _ => None
        }
}
