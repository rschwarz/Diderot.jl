# Diderot.jl

Decision Diagrams for Optimization in Julia.

[![Build Status](https://travis-ci.com/rschwarz/Diderot.jl.svg?branch=master)](https://travis-ci.com/rschwarz/Diderot.jl)
[![Codecov](https://codecov.io/gh/rschwarz/Diderot.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rschwarz/Diderot.jl)

Provides a generic implementation of decisision diagrams (top-down construction
of layered state transition graph). Supports restrictions and relaxations
through user-defined layer processing. Implements simple branch-and-bound based
on subproblems defined by nodes in an exact cutset of the diagram.

## Usage

The user has to implement several methods to define the model. These are
dispatched over user-defined types for the instance data and states.

```julia
# for decision variables, e.g. Int
domain_type(instance)

# for objective function, e.g. Float64
value_type(instance)

# number of decision variables == depth of decision diagram
Base.length(instance)

# used for root node, e.g. capacity as Int
intial_state(instance)

# state transition function, including cost
transitions(instance, state, variables)

# optional: dynamic variable order as index
next_variable(instance, diagram, variable_order)
```

This already allows solving problems by generating the exact (complete) decision
diagram and extracting the values following a longest path.

```julia
diagram = Diagram(instance)
top_down!(diagram, instance)
solution = longest_path(diagram)
```

To use the branch-and-bound algorithm, two strategies for restriction and
relaxation of the diagram have to be provided.

```julia
solution = branch_and_bound(instance, restrict=Restrict(), relax=Relax())
```

## Limitations

This is (still) mostly a naive text book implementation for learning purposes.
I'm sure there's room for improvement in the choice of data structures and
avoing frequent allocation.

It's currently assumed that the objective function is to be maximized, and the
transition values are combined by addition. That is, we're looking for a longest
path in the diagram, using as arc weights the values of the transitions. In
principle, one could also choose minimization or use another operator
(multiplication, maximum), but this would require even more type
parametrization.

The decision diagram does not keep all transition arcs, but computes the longest
path on the fly. That is, after a new layer is created, each node only remembers
a single ingoing arc. This simplification works OK for the purpose of finding an
optimal solution, but it rules out other use cases, such as enumeration of
feasible solutions or post-optimality analysis.

## Problem Classes

Models and methods for some specific problem classes are also implemented in the
context of this package as submodules. The main motivation is test-driving the
current API, to make sure it's sufficiently general and not too verbose.

This currently includes only the Knapsack Problem.

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
