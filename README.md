# BibBlitz 📚⚡

A program to convert a JSON file into a `.bibtex` file using CrossRef.

## Usage

Given a JSON file `refs.json` with the content:

```json
{
    "lutze2023": "10.1145/3656393"
}
```

You can create a `refs.bib` by running:

```sh
java -jar BibBlitz.jar refs.json refs.bib
```

which will lookup the meta data using CrossRef.
