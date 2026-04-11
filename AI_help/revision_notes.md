# Revision Notes

## Purpose

This note records the recent text revisions made in the LaTeX thesis, with
focus on the Introduction, Conclusion, Abstract, and the opening/summary
paragraphs in Chapters 2 and 4.

The overall editing goal was:

- reduce template-like academic phrasing
- make conclusions more clearly tied to this thesis and its own evidence
- replace broad generic claims with scoped statements linked to the tested
  platform, matrix family, and measured results
- preserve the technical meaning of the thesis while making the prose more
  specific and less uniform in tone

## Files Revised

- `latex/main.tex`
- `latex/chapters/01_Introduction/01_introduction.tex`
- `latex/chapters/02_Mathematical_Foundations/02_00.tex`
- `latex/chapters/02_Mathematical_Foundations/02_04.tex`
- `latex/chapters/04_Experiments/04_00.tex`
- `latex/chapters/04_Experiments/04_03_blas.tex`
- `latex/chapters/04_Experiments/04_04_simd.tex`
- `latex/chapters/04_Experiments/04_06_summary.tex`
- `latex/chapters/05_Conclusion/05_01_main_findings.tex`
- `latex/chapters/05_Conclusion/05_02_practical_guidance.tex`
- `latex/chapters/05_Conclusion/05_03_limitations.tex`
- `latex/chapters/05_Conclusion/05_04_future_work.tex`

## Chapter 1: Introduction

File:

- `latex/chapters/01_Introduction/01_introduction.tex`

What changed:

- Rewrote the opening paragraphs so the chapter starts from dense real
  symmetric eigenvalue problems and the mathematical comparison between QR
  iteration and divide-and-conquer.
- Added a TikZ figure showing the standard three-stage route:
  orthogonal reduction, tridiagonal eigensolution, and back transformation.
- Moved `DSYEV` and `DSYEVD` from being the opening focus to being the concrete
  LAPACK implementation setting.
- Restored the application/significance section so it discusses the
  mathematical and physical meaning of symmetric eigenproblems before software
  details.
- Reworked the motivating comparison section so it points more directly to the
  later Chapter 4 evidence.
- Rewrote the scope/contribution section so the central comparison is
  QR-based versus divide-and-conquer approaches, with LAPACK as the
  implementation and experimental context.
- Retained Sections 1.4 and 1.5, but changed Section 1.4 from
  `Scope and Main Contributions` to `Scope and Project Aims` to better match a
  coursework project.
- Revised Section 1.2 so it explains why LAPACK/BLAS is an appropriate
  implementation context, rather than presenting detailed driver internals too
  early.
- Simplified the organization paragraph to sound less like a template roadmap.

How it was changed:

- The introduction no longer opens with "a concrete choice inside LAPACK".
- The first paragraph now names the mathematical problem and the two algorithmic
  approaches before introducing LAPACK.
- The opening now includes the formulas
  `T = Q^{-1} A Q`, `Lambda = U_T^{-1} T U_T`, and
  `Lambda = U_A^{-1} A U_A`, together with `U_A = Q U_T`.
- LAPACK references are concentrated in the implementation-context and
  motivating-comparison sections.
- Section 1.2 now introduces LAPACK/BLAS at the level of numerical software
  context, work organization, and practical performance, leaving detailed
  driver structure to Chapter 3.
- The contribution statements were rewritten to emphasize:
  - QR versus divide-and-conquer
  - the tridiagonal eigensolver stage
  - LAPACK as the concrete implementation setting
  - the runtime/workspace tradeoff
- Section 1.5 was kept as a short thesis-structure paragraph rather than a long
  template-style roadmap.

## Abstract

File:

- `latex/main.tex`

What changed:

- Rewrote the abstract so it begins from the mathematical eigenvalue problem
  rather than from LAPACK driver names.
- Presented the thesis as a mathematics-plus-implementation-plus-experiment
  study.
- Removed overly detailed experimental-environment information from the
  abstract.
- Kept the LAPACK routines in the abstract only after the mathematical and
  algorithmic context has been established.

How it was changed:

- The abstract now starts from real symmetric eigenvalue problems and the cost
  of computing dense eigenvectors.
- It then introduces the QR and divide-and-conquer approaches before naming
  `DSYEV`, `DSYEVD`, `DSTEQR`, and `DSTEDC`.
- Specific platform details such as OpenBLAS SVE, ARM, KMS matrices, and exact
  timing values were removed from the abstract because they belong in the
  experimental chapter rather than in the thesis summary.
- The final recommendation remains framed as a runtime-workspace tradeoff
  rather than a universal ranking.

## Chapter 2: Mathematical Foundations

Files:

- `latex/chapters/02_Mathematical_Foundations/02_main.tex`
- `latex/chapters/02_Mathematical_Foundations/02_00.tex`
- `latex/chapters/02_Mathematical_Foundations/02_01_SYTRD.tex`
- `latex/chapters/02_Mathematical_Foundations/02_02_STEQR.tex`
- `latex/chapters/02_Mathematical_Foundations/02_03_STEDC.tex`
- `latex/chapters/02_Mathematical_Foundations/02_04.tex`

What changed:

- Reworked Chapter 2 back toward a purely mathematical presentation.
- Changed the chapter title from a `syev`/`syevd`-oriented title to
  `Mathematical Foundations of Symmetric Eigenproblems`.
- Removed the framing that Chapter 2 contains only what is needed for the later
  `DSYEV`/`DSYEVD` comparison.
- Removed visible LAPACK routine names from the main section titles.
- Reworked the comparison section opening and conclusion so they describe the
  two tridiagonal eigensolvers mathematically, without pointing forward to
  LAPACK drivers.

How it was changed:

- The chapter opening now starts from real symmetric eigenvalue problems,
  orthogonal similarity, tridiagonal reduction, and tridiagonal
  eigensolvers.
- Section titles now use mathematical names:
  - `Householder Tridiagonalization`
  - `Implicit QR/QL Iteration for Symmetric Tridiagonal Matrices`
  - `Divide-and-Conquer Method for Tridiagonal Eigenproblems`
- The QR/QL section now describes the mathematical iteration rather than
  presenting it as the task of a LAPACK routine.
- The divide-and-conquer section now explains the split, rank-one correction,
  secular equation, recursion, and eigenvector reconstruction without using
  LAPACK implementation as the narrative endpoint.
- The comparison section now emphasizes:
  - same spectral target
  - different computational organization
  - local rotation-heavy QR/QL work
  - recursive split/merge divide-and-conquer work
  - different workspace and cost behaviour

## Chapter 4: Experiments

Files:

- `latex/chapters/04_Experiments/04_00.tex`
- `latex/chapters/04_Experiments/04_03_blas.tex`
- `latex/chapters/04_Experiments/04_04_simd.tex`
- `latex/chapters/04_Experiments/04_06_summary.tex`

What changed:

- Rewrote the chapter opening to be driven by three explicit empirical
  questions.
- Reworked the BLAS-impact section introduction and interpretation paragraph.
- Reworked the SIMD section introduction and interpretation paragraph.
- Rewrote the final synthesis section to reduce layered template summary
  language and make the argument more evidence-driven.

How it was changed:

- The chapter opening now asks:
  - which driver is faster
  - which stage creates the gap
  - how much of that gap comes from algorithm, implementation, and SIMD
- The BLAS section now states more directly that the routine comparison is
  fixed while the implementation stack changes.
- The BLAS interpretation paragraph now highlights the uneven stage gains using
  the measured values:
  - `DSTEQR` near `1.0x`
  - `DSTEDC` roughly `2.6x` to `5.1x`
  - back-transform stages roughly `5.9x` to `7.8x`
- The SIMD section now presents SVE as an incremental gain on top of an already
  optimized blocked path, not as the main explanation.
- The final synthesis section now ties the conclusion tightly to specific
  measured facts:
  - `DSTEDC` tri-eig speedup range
  - `n=4096` total times
  - shared `DSYTRD` cost
  - `DGEMM` shares inside `DSTEDC` and `DORMTR`

## Chapter 5: Conclusion

Files:

- `latex/chapters/05_Conclusion/05_01_main_findings.tex`
- `latex/chapters/05_Conclusion/05_02_practical_guidance.tex`
- `latex/chapters/05_Conclusion/05_03_limitations.tex`
- `latex/chapters/05_Conclusion/05_04_future_work.tex`

What changed:

- Rewrote all four sections of Chapter 5.
- Reduced generic summary phrasing such as numbered "first/second/third
  conclusion" structures.
- Replaced broad conclusions with statements anchored to Chapter 4 data and
  scope.

How it was changed:

- `Main Findings` now uses concrete evidence:
  - `66.255 s` vs `14.482 s`
  - `55.793 s` vs `1.935 s`
  - `260.6 MiB` vs `521.6 MiB`
- `Practical Guidance` now frames recommendations within the tested KMS /
  OpenBLAS / ARM setting instead of stating them as general advice.
- `Limitations` now describes boundaries more specifically:
  platform, library stack, matrix family, tested sizes, and performance
  criteria.
- `Future Work` now follows naturally from the actual experiments:
  more libraries, more matrix families, broader metrics, and accelerator /
  distributed settings.

## Main Editing Pattern

Across all revised sections, the same editing pattern was applied.

Before:

- broad importance claims
- smooth chapter-roadmap prose
- generic summary transitions
- conclusions stated at a high level without immediate evidence
- repeated thesis-style phrasing such as "this section", "this thesis", "the
  main conclusion", "taken together", and similar stock academic transitions

After:

- direct statement of the thesis-specific problem
- explicit mention of routines and stages
- use of representative measured numbers where available
- clearer scope boundaries
- stronger link between theory, LAPACK implementation, and experiment
- less uniform sentence rhythm in opening and closing paragraphs

## Verification

The revised thesis was compiled with `pdflatex`.

Status:

- compilation succeeded
- updated `main.pdf` was generated
- no new LaTeX syntax errors were introduced by these text revisions

Remaining warnings are mostly pre-existing formatting issues such as:

- long-line `Overfull \hbox` warnings in some older sections
- bibliography URL line-breaking warnings
- the class-name warning from `unswthesis`
