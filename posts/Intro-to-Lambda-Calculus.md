---
aliases: 
title: Intro to Lambda Calculus
author: Hamish
date: 2025-03-30
is_post: "true"
---
I watched an [amazing video](https://youtu.be/RcVA8Nj6HEo?si=Lq33hT6xXRFeGiHz) the other day that showed me a aspect of math and computer science that I've surprisingly neglected throughout my degree. It's called Lambda Calculus, created my Alonzo Church, and its a formal language to express computation based on functional abstraction and application using variable binding and substitution. 

(WIP I have not finished this :P)


## Functions

- What is a function?
- Input - blockbox - output
- In lambda calculus, a the notation for the definition of a function is $\lambda$ 
- For the function that takes an input $x$, and outputs $x+1$ it would be written as $\lambda x.x+1$
- The $.$ separates the input from the output of the function


## Applying Functions

- Say we have $\lambda x.x+1$
- If we wanted to 'apply' it to 3 (meaning putting 3 as the input of the function), we surround the function in brackets and put the number to next to it
- Like: $(\lambda x.x+1)3$
- To 'apply' it to this, we have to do a *beta reduction* on the function
- This mean we substitute in the applicator (3) everywhere in the function output ($x+1$) where the input term ($x$) is mentioned.
- Meaning $(\lambda x.x+1)3=\beta (3+1)=4$

## Currying

> The technique of transforming a function that takes multiple arguments into a function that takes a single argument (the first of the arguments to the original function) and returns a new function that takes the remainder of the arguments and returns the result.
> - *Wiktionary*

- One of the requirements of lambda calculus is that a function can only have one input.
- But what if we wanted a function that takes more parameters, for example a function that takes input $x,y$ and outputs $x+y$.
- Haskell Curry found a interesting way to get around this with the use of **Higher Order Functions**
- Higher order functions are functions from return another function as its output

Heres an examples:
$$\lambda x.\lambda y. x+y$$

So the first (outer) function takes an input of $x$, and returns $\lambda y. x+y$
The second function takes $y$ and returns $x+y$.
To apply the two parameters to a function like this, we put the variables next to it in order of outer to inner

**Applying**

$$(\lambda x.\lambda y. x+y)1\ 2$$

Lets beta reduce this step by step:

$$\beta (\lambda y.1+y)2$$
$$\beta (1+2)=3$$

