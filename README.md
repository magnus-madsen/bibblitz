# BibBlitz 📚⚡

A program to convert a JSON file into a `.bibtex` file using CrossRef.

## Usage

Given a JSON file `refs.json` with the content:

```json
{
  "lutze2023": "10.1145/3607846",
  "lutze2024": "10.1145/3656393",
  "madsen2025": "10.1145/3763126"
}
```

You can create a `refs.bib` by running:

```sh
java -jar bibblitz.jar refs.json refs.bib
```

The program will fetch metadata from CrossRef and display progress:

```
[Info] Parsed 'refs.json'. Found 3 DOIs.
[Info] Fetching data from CrossRef.
[Info] [1/3] Fetched 'lutze2023'.
[Info] [2/3] Fetched 'lutze2024'.
[Info] [3/3] Fetched 'madsen2025'.
[Info] Wrote BibTeX entries to 'refs.bib'.
```

### Example Output

The generated `refs.bib` file will contain:

```bibtex
@article{lutze2023,
  title     = {With or Without You: Programming with Effect Exclusion},
  author    = {Lutze, Matthew and Madsen, Magnus and Schuster, Philipp and Brachthäuser, Jonathan Immanuel},
  journal   = {Proceedings of the ACM on Programming Languages},
  volume    = {7},
  pages     = {448-475},
  publisher = {Association for Computing Machinery (ACM)},
  doi       = {10.1145/3607846}
}

@article{lutze2024,
  title     = {Associated Effects: Flexible Abstractions for Effectful Programming},
  author    = {Lutze, Matthew and Madsen, Magnus},
  journal   = {Proceedings of the ACM on Programming Languages},
  volume    = {8},
  pages     = {394-416},
  publisher = {Association for Computing Machinery (ACM)},
  doi       = {10.1145/3656393}
}

@article{madsen2025,
  title     = {Flix: A Design for Language-Integrated Datalog},
  author    = {Madsen, Magnus and Lhoták, Ondřej},
  journal   = {Proceedings of the ACM on Programming Languages},
  volume    = {9},
  pages     = {2115-2143},
  publisher = {Association for Computing Machinery (ACM)},
  doi       = {10.1145/3763126}
}
```
