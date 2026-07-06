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

pub mod JsonUtils {
    use Util.Json

    /// Gets a string field from a JSON object
    pub def getJsonString(obj: Map[String, Json], key: String): Option[String] =
        match Map.get(key, obj) {
            case Some(Json.JString(s)) => Some(s)
            case _                     => None
        }

    /// Gets a field that is either a string or an array of strings from a JSON object
    pub def getJsonStrings(obj: Map[String, Json], key: String): List[String] =
        match Map.get(key, obj) {
            case Some(Json.JString(s)) => s :: Nil
            case Some(Json.JArray(a))  => Vector.toList(a) |> List.filterMap(j -> match j {
                case Json.JString(s) => Some(s)
                case _               => None
            })
            case _                     => Nil
        }

    /// Gets an array field from a JSON object
    pub def getJsonArray(obj: Map[String, Json], key: String): Option[List[Json]] =
        match Map.get(key, obj) {
            case Some(Json.JArray(a)) => Some(Vector.toList(a))
            case _                    => None
        }

    /// Gets an object field from a JSON object
    pub def getJsonObject(obj: Map[String, Json], key: String): Option[Map[String, Json]] =
        match Map.get(key, obj) {
            case Some(Json.JObject(o)) => Some(o)
            case _                     => None
        }
}
