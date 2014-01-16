---
layout: default
title: Coercing Expressions to Functions in Ides
comments: true
---

[The Ides programming language](http://ides-lang.com), for the uninitiated, is my own attempt at designing a modern, multiparidigm systems programming language. It is heavily inspired by [Scala](http://www.scala-lang.org/) and [Rust](http://www.rust-lang.org/), and is built on [LLVM](http://llvm.org/).

Inference and Coercion
======================

Ides functions implement the trait `Function[Ret : Any, Args : Any...]`[^1]. 

[^1]: The type argument `Ret`, which is bound to subtypes of `Any`, is always present and represents the function's return type. The type argument `Args` may be zero or more types, each a subtype of `Any`, representing the types of the arguments to the function.