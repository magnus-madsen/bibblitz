# BibBlitz 📚⚡

A program to convert a JSON file into a `.bibtex` file using CrossRef and DataCite.

## Usage

Given a JSON file `refs.json` with the content:

```json
{
  "lutze2023": "10.1145/3607846",
  "lutze2024": "10.1145/3656393",
  "madsen2023": "10.4230/LIPIcs.ECOOP.2023.18",
  "madsen2025": "10.1145/3763126"
}
```

You can create a `refs.bib` by running:

```sh
java -jar bibblitz.jar refs.json refs.bib
```

The program will fetch metadata from CrossRef and DataCite and display progress:

```
[Info] Parsed 'refs.json'. Found 4 DOIs.
[Info] Fetching data from CrossRef and DataCite.
[Info] [1/4] Fetched 'lutze2023'.
[Info] [2/4] Fetched 'lutze2024'.
[Info] [3/4] Fetched 'madsen2023'.
[Info] [4/4] Fetched 'madsen2025'.
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
  publisher = {Association for Computing Machinery (ACM)},
  doi       = {10.1145/3607846}
}

@article{lutze2024,
  title     = {Associated Effects: Flexible Abstractions for Effectful Programming},
  author    = {Lutze, Matthew and Madsen, Magnus},
  journal   = {Proceedings of the ACM on Programming Languages},
  volume    = {8},
  publisher = {Association for Computing Machinery (ACM)},
  doi       = {10.1145/3656393}
}

@inproceedings{madsen2023,
  title     = {Programming with Purity Reflection: Peaceful Coexistence of Effects, Laziness, and Parallelism},
  author    = {Madsen, Magnus and van de Pol, Jaco},
  journal   = {LIPIcs, Volume 263, ECOOP 2023},
  volume    = {263},
  publisher = {Schloss Dagstuhl – Leibniz-Zentrum für Informatik},
  doi       = {10.4230/lipics.ecoop.2023.18}
}

@article{madsen2025,
  title     = {Flix: A Design for Language-Integrated Datalog},
  author    = {Madsen, Magnus and Lhoták, Ondřej},
  journal   = {Proceedings of the ACM on Programming Languages},
  volume    = {9},
  publisher = {Association for Computing Machinery (ACM)},
  doi       = {10.1145/3763126}
}
```
