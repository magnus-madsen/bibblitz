/*
 * Copyright 2025 Magnus Madsen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
