# Diderot.jl

<img align="right" src="docs/src/assets/logo.svg">

Decision Diagrams for Discrete Optimization in Julia.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rschwarz.github.io/Diderot.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://rschwarz.github.io/Diderot.jl/dev)
[![Build Status](https://github.com/rschwarz/Diderot.jl/workflows/CI/badge.svg?branch=master)](https://github.com/rschwarz/Diderot.jl/actions?query=workflow%3ACI)
[![Codecov](https://codecov.io/gh/rschwarz/Diderot.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rschwarz/Diderot.jl)

Provides a generic implementation of decision diagrams (top-down construction
of layered state transition graph). Implements a branch-and-bound algorithms
with subproblems defined by nodes in an exact
[cutset](https://en.wikipedia.org/wiki/Vertex_separator) of the diagram.

To support new problem classes, several methods have to be implemented that
are dispatched on the user-defined types for the instance, describing the states
and transitions.

The solver behavior (restrictions, relaxations, variable order, diagram width)
can be fully customized through user-defined layer processing.

## Motivation

The package is mostly written as a learning experiment.
The appeal (for me) of using decision diagrams to solve discrete optimization
problems is two-fold:

1. The simplicity of the algorithm makes implementation from scratch a
   reasonable endeavor.
2. It seems that the DD-based branch-and-bound lends itself to parallelization,
   yielding better speed-ups than MIP solvers.

## Limitations

This is (still) mostly a naive text book implementation. I'm sure there's room
for improvement in the choice of data structures and avoiding frequent allocations.

It's currently assumed that the objective function is to be maximized, and the
transition values are combined by addition. That is, we're looking for a longest
path in the diagram, using as arc weights the values of the transitions. In
principle, one could also choose minimization or use another operator
(multiplication, maximum), but this would require even more type
parametrization.

The decision diagram does not keep all transition arcs, but computes the longest
path on the fly. That is, after a new layer is created, each node only remembers
a single ingoing arc. This simplification works OK for the purpose of finding an
optimal solution, but it rules out other use cases such as the enumeration of
feasible solutions or post-optimality analysis.

## Problem Classes

Models and methods for some specific problem classes are implemented in the
context of this package as submodules. The main motivation is to test-drive the
current API, to make sure it's sufficiently general and not too verbose.

Currently included are:
- Binary Knapsack Problem.
- Set Cover Problem.
- Index Fund Construction (as defined in [Optimization Methods in Finance](https://doi.org/10.1017/9781107297340))

## References

The implementation is informed by the book
[Decision Diagrams for Optimization](https://www.springer.com/us/book/9783319428475)
by D Bergman, A Cire, WJ van Hoeve and J Hooker.

The [MDD website](http://www.andrew.cmu.edu/user/vanhoeve/mdd/) also contains a
lot of valuable resources, in particular the INFORMS article
[Discrete Optimization with Decision Diagrams](http://www.andrew.cmu.edu/user/vanhoeve/papers/discrete_opt_with_DDs.pdf).

## Contributions

Pull requests with various forms of contributions are very welcome. In
particular, I would appreciate suggestions to simplify the current interface,
improve overall performance or cover more problem classes.

## Related Work

- [DDX10](http://www.andrew.cmu.edu/user/vanhoeve/mdd/code/DDX10.zip): Parallel branch-and-bound (C++, X10).
- [ryanjoneil/tsppd-dd](https://github.com/ryanjoneil/tsppd-dd): TSP with pickup and delivery times (Go).
- [rkimura47/pymdd](https://github.com/rkimura47/pymdd): Generic implementation of MDDs (Python).
- [ac-tuwien/pymhlib](https://github.com/ac-tuwien/pymhlib/blob/master/pymhlib/decision_diag.py): DD-based relaxation (Python).
- [vcoppe/mdd-solver](https://github.com/vcoppe/mdd-solver): Generic solver library (Java).
- [xgillard/ddo](https://github.com/xgillard/ddo): Generic solver (Rust).
