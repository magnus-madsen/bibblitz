mod CrossRef {
    use Json.JsonElement

    /// Fetches CSL-JSON metadata for a given DOI from CrossRef
    pub def fetchCslJson(doi: String): Result[String, JsonElement] \ Http =
        use Json.Parse.parse;
        let url = "https://api.crossref.org/works/${doi}/transform/application/vnd.citationstyles.csl+json";
        let headers = Map#{};
        let Http.Response.Response(r) = Http.get(url, headers);
        match parse(r#body) {
            case Some(json) => Ok(json)
            case None => Err("Failed to parse JSON")
        }

    /// Fetches CSL-JSON and converts to BibTeX for a single reference
    pub def fetchBibTeX(name: String, doi: String): Result[String, String] \ Http =
        match fetchCslJson(doi) {
            case Err(e) => Err(e)
            case Ok(cslJson) => match Bibtex.cslToBibTeX(name, cslJson) {
                case Some(bibtex) => Ok(bibtex)
                case None => Err("Failed to convert to BibTeX")
            }
        }
}
