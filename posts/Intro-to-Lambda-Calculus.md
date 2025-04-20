---
aliases: 
title: Intro to Lambda Calculus
author: Hamish
date: 2025-03-30
is_post: "true"
---
I watched an [amazing video](https://youtu.be/RcVA8Nj6HEo?si=Lq33hT6xXRFeGiHz) the other day that showed me an aspect of math and computer science that I've surprisingly neglected throughout my degree. It's called Lambda Calculus, created by Alonzo Church, and it’s a formal system designed to express computation purely through function abstraction, application, and substitution.

## Functions

- A **function** is essentially a process or "black box" that takes an input, performs some computation, and returns an output.
    
- In Lambda Calculus, the notation for defining a function uses the Greek letter $\lambda$.
    
- For a function that takes input $x$ and outputs $x + 1$, we write it as: $\lambda x.x + 1$.
    
- The dot `.` separates the input parameter from the function body (the computation or output).
    

## Applying Functions

- Consider the function $\lambda x.x + 1$.
    
- To apply this function to a specific input, say `3`, you place the input next to the function enclosed in parentheses: $(\lambda x.x + 1)\ 3$.
    
- To compute the result, we perform a **beta reduction**.
    
- **Beta reduction** means substituting the given input (`3`) everywhere the parameter (`x`) appears in the function body.
    
- So: $(\lambda x.x+1)\ 3 = \beta (3+1) = 4$
    

## Currying

Currying transforms a function that takes multiple arguments into a series of single-argument functions. This is useful since Lambda Calculus requires that every function takes exactly one input.

- For instance, how would you represent a function that takes two parameters, $x$ and $y$, and returns $x + y$?
    
- Haskell Curry introduced the idea of **higher-order functions**—functions that return other functions—as a clever solution.
    

Here's how it looks in Lambda notation:

$\lambda x.\lambda y.x + y$

- The outer function takes an input `x`, returning a new function $\lambda y.x + y$.
    
- The inner function then takes another input `y` and returns `x + y`.
    

**Applying the curried function:**

If we apply this function to inputs `1` and `2`, it looks like:

$(\lambda x.\lambda y.x + y)\ 1\ 2$

Performing beta reductions step-by-step:

$\beta (\lambda y.1 + y)\ 2$
$\beta (1 + 2) = 3$

Currying lets us break down multi-argument functions into simpler, composable building blocks. This is fundamental in functional programming languages like Haskell and helps with modularity and partial application.
