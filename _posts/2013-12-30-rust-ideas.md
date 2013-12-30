---
layout: default
title: "My Rusty Wishlist"
comments: true
---

I've been spending some time with Rust lately, and I thought I'd write down some ideas of what I would like to see, listed roughly in the order that I would like to see them.

While the intention with each of these items is to retain backwards compatibility, this post is a wishlist, and was written with a reckless disregard for implementation details.

Single-Inheritance of Structs
=============================

This one is pretty self-explanatory. I want object-oriented style polymorphism in structs.

{% highlight rust %}
struct A;

struct B : A;

impl A {
    fn test() { println("Hello, world"); }
}

fn main() {
    let val : B;
    val.test(); // prints "Hello, world"
}

{% endhighlight %}

I don't know much about the implementation details of this. I would be satisfied with a separate type of data structure, perhaps `class`, which can only exist in a boxed pointer.

**Update:** It appears such a proposal, in much more detail, [already exists](http://smallcultfollowing.com/babysteps/blog/2013/10/24/single-inheritance/).

Functions and Traits
====================

Taking a note from Scala, it would be convenient to have a trait, or set of traits, that represented functions themselves. Scala represents these through [`Function1`](http://www.scala-lang.org/api/current/index.html#scala.Function1) (and `Function2`, `Function3`, up through `Function22` for [semi-arbitrary reasons](http://stackoverflow.com/a/4152416/53315)).

Function call semantics, then, are translated to a call to the `apply()` method on the implementing object (obviously with some specialization for actual functions). This leads to a natural way of expressing closures: an anonymous struct implementing a function trait.

Personally, for Rust, I think names like `Fn1`, `Fn2`, etc. are more appropriate, as they map nicely to the `fn` keyword. I'll refer to the hypothetical function traits by these names in the next sections.

Partial Functions
=================

Again, taking a note from Scala here. An expression of the form:

{% highlight rust %}
{
    <pattern> => { <expression> }
    ...
}
{% endhighlight %}

is compiled as though it was a generic function that accepts an argument of any of the supplied pattern types, with a fallback that runs `fail!`. The expression itself is an anonymous type implementing the trait [`PartialFunction<R, T>`](http://www.scala-lang.org/api/current/index.html#scala.PartialFunction), inheriting from `Fn1<R, T>` (see above) where `T` is the common supertype (possibly `Any`) of all patterns, and `R` is the type of all of the expressions.

Importantly, the `PartialFunction<R, T>` trait defines an `is_defined(T) -> bool` method to test in advance for a definition for that type in the domain.

Finally, the `match` expression now takes the form:

{% highlight rust %}
match x y
{% endhighlight %}

where `x` is any expression of type T, and `y` is any `PartialFunction<R, T>`.

If `[]` operator was defined as an alias to `apply()` on partial functions, this would also be a very slick way of defining static lookup tables within the language:

{% highlight rust %}
let table = {
    "hello" => "world",
    "foo" => "bar"
};

println(table["hello"]) // prints: "world"
{% endhighlight %}

This works in Scala as well, because collection indexing uses the syntax of a function call. (You guessed it, [`apply()`](http://www.scala-lang.org/api/current/index.html#scala.Array).)

Default and Named Arguments
===========================

The usefulness of both of these is probably obvious. Where I really want to see it used is in `#[deriving(Clone)]`:

{% highlight rust %}
#[deriving(Clone)]
struct S {
    a: i32,
    b: i32
}

pub fn main() {
    // Clones the struct and assigns a=3 while retaining immutability semantics.
    // Function looks like: fn clone(&self, a: i32 = self.a, b: i32 = self.b) { S { a: a, b: b } }
    let _ = S { a: 1, b: 2 }.clone(a=3);
}
{% endhighlight %}
