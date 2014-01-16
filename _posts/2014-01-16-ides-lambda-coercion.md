---
layout: default
title: "The Ides Language: Lambas and Coercion Rules"
comments: true
---

The Ides programming language, for the uninitiated, is my own attempt at designing a modern, multiparidigm systems programming language. It is heavily inspired by [Scala](http://www.scala-lang.org/) and [Rust](http://www.rust-lang.org/), and is built on [LLVM](http://llvm.org/). This post is a brief overview of some aspects of the language's coercion rules as they apply to lambda expressions.

These ideas are works in progress, and feedback is welcome.

Inference and Coercion
======================

Type inference and type coercion can be thought of as opposite operations. With type inference, types implicitly float *upward* through the expression tree:

{% highlight scala %}
val x = 5;
{% endhighlight %}

<img src="/dot/2014-01-16-inference1.dot.png" />

Conversely, with type coercion, types are implicitly forced *downward* through the expression tree:

{% highlight scala %}
val x : float32 = 5;
{% endhighlight %}

<img src="/dot/2014-01-16-inference2.dot.png" />

Both of these are used extensively in idiomatic Ides code.

Coercion to Functions
=====================

Ides functions implement the trait `Function[Ret: Any, Args: Any...]`[^1]. Functions are first-class values that can be accepted as arguments to other functions. For example, suppose we have a function that allows you to set the random number generator used by some system:

{% highlight scala %}
def setRNG(rng: Function[int32]);
{% endhighlight %}

Ides allows any expression of type `T` to be coerced to a `Function[R]` (a function which accepts zero arguments and returns a value of type `R`) if `T` (the type of the expression) can be coerced to `R` (the return type).

This means that, if we determine that a single [fair dice roll](http://xkcd.com/221/) is a sufficient quality of randomness, we could define the random number generator as follows:

{% highlight scala %}
setRNG(4);
{% endhighlight %}

The expression will be coerced to an expression of type `Function[int32]`, and will be evaluated when the resulting function is called.

Lambdas and Placeholders
========================

A placeholder is an expression with no type, but which may be coerced to any type. Placeholders are only valid in an expression tree that the compiler will coerce to a function:

{% highlight scala %}
// BAD: f can't be assigned to a value of no type.
val f = :1;
{% endhighlight %}
{% highlight scala %}
// OK: :1 is coerced to the type of the first argument (int32),
//     and then coerced to the return type (float64).
val f = (:1 as Function[float64, int32]);

// OK: x = 5.0
val x = f(5);
{% endhighlight %}

It would be cumbersome if this was the only way to define lambdas. Ides also provides the `->` operator, which allows for a more verbose, but more flexible way of creating lambda expressions:

{% highlight scala %}
// OK: Argument is named and typed explicitly.
val f = (x : int32) -> x;

// OK: x = 5
val x = f(5);
{% endhighlight %}

The special placeholder `:0` always corresponds to the immediately enclosing function. `:0` may be used in any function context, not including constructors.

Defining Valid Coercions
========================

Ides provides two mechanisms for declaring new coercions: implicit auxilary constructors, and the `CoerceTo[T]` trait.

Implicit Auxilary Constructors
------------------------------

Ides borrows the concept of primary and auxilary constructors from Scala[^2]. In addition to standard auxilary constructors, a programmer may define any number of *implicit* auxilary constructors:

{% highlight scala %}
class A(s: String) => {
    implicit def this(s: String) => A(s);
}
{% endhighlight %}

This defines the process for coercing a value of type `String` to a value of type `A`. Semantically, this is a coercion *from* a `String`.

`CoerceTo[T]`
-------------

A class may also implement the trait `CoerceTo[T]` by providing a single method, `to()` which returns a value of type `T`[^3]:

{% highlight scala %}
class B(s: String) : CoerceTo[A] => {
    def to() : A => A(s);
}
{% endhighlight %}

This defines the process for coercing a value of type `B` to a value of type `A`. Semantically, this is a coercion *to* type `A`.

If multiple valid coercions exist, `CoerceTo[T]` will always take precedence over implicit constructors.

Some Fun Examples
=================

Recursive calculation of the nth fibonacci number:
{% highlight scala %}
val fib = (n : int32) -> if (n <= 1) 1 else :0(n - 1) + :0(n - 2)
{% endhighlight %}

Calculating n factorial:
{% highlight scala %}
val factorial = (n : int32) -> (1 to n).fold(1, :1 * :2)
// Note: The second argument to fold() is actually a second lambda expression.
// :1 and :2 in this context do not refer to arguments to factorial() itself.
{% endhighlight %}

Lazy values, implemented without the need for explicit language support:
{% highlight scala %}
class Lazy[T : Any](func : Function[T]) : CoerceTo[T] => {
    // Coercions can be chained.
    // An expression of type T is implicitly coerced to a lambda
    // before being passed here:
    implicit def this(f: Function[T]) => this(f);

    // The Lazy[T] can be used as though it was a value of type T.
    // When coerced to a T, the actual value is retrieved once 
    // from the function and cached for further coercions.
    def to() : T => value match {
        case Some(v) => v
        case None => { value = Some(func()); value.get(); }
    }

    private var value : Option[T];
}
{% endhighlight %}

[^1]: The type argument `Ret`, which is bound to subtypes of `Any`, is always present and represents the function's return type. The type argument `Args` may be zero or more types, each a subtype of `Any`, representing the types of the arguments to the function.

[^2]: [The Scala Language Specification](http://www.scala-lang.org/docu/files/ScalaReference.pdf) &sect; 5.3.1

[^3]: Unlike many other statically typed languages, Ides allows functions to be overloaded by return type, and uses coercion rules to disambiguate between otherwise identical methods. This allows `CoerceTo[T]` to be implemented for multiple types of `T`.