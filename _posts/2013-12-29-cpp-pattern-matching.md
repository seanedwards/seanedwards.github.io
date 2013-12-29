---
layout: default
title: "Partial Pattern Matching in C++11"
subtitle: "Or: continuing adventures in template hell"
comments: true
---

After being spoiled by Scala's [pattern matching](http://docs.scala-lang.org/tutorials/tour/pattern-matching.html), I became frustrated by the verbosity required to implement the [visitor pattern](https://en.wikipedia.org/wiki/Visitor_pattern) in C++. After some thought, it seemed like the visitor pattern could be abstracted away using templates.

We start with a function, called `Match`, which begins a match expression:

{% highlight cpp %}
// The template argument is the return type of the match expression.
template<typename Ret = void>
MatchCase<Ret> Match() {
    return MatchCase<Ret>();
}
{% endhighlight %}

`MatchCase` does the bulk of the work:

{% highlight cpp %}
template<typename Ret, typename T, typename... Args>
class MatchCase<Ret, T, Args...> {

    // Make our parent a friend so we don't have to give the whole world constructor access.
    friend class MatchCase<Ret, Args...>;

    public:

    template<typename A>
    MatchCase<Ret, A, T, Args...> on(const std::function<Ret(A*)>& func) {
        return MatchCase<Ret, A, T, Args...>(func, std::move(*this));
    }

    template<typename A>
    Ret match(A* val) const {
        if (T* v = dynamic_cast<T*>(val)) {
            return func(v);
        }
        return parent.match(val);
    }

    private:

    MatchCase(const std::function<Ret(T*)>& func, const MatchCase<Ret, Args...>& super) 
        : parent(super), func(func) { }

    const MatchCase<Ret, Args...> parent;
    const std::function<Ret(T*)> func;
};
{% endhighlight %}

A specialized base case handles an unmatched pointer:

{% highlight cpp %}
template<typename Ret, typename... Args>
class MatchCase {
    public:

    template<typename A>
    MatchCase<Ret, A, Args...> on(const std::function<Ret(A*)>& func) {
        return MatchCase<Ret, A, Args...>(func, std::move(*this));
    }

    template<typename A>
    Ret match(A* val) const {
        // TODO: Pick a better exception type.
        throw std::runtime_error("No such pattern.");
    }
};
{% endhighlight %}

Finally, we're able to map types to lambdas in a single expression, which is all anyone really wants.

Using the following object hierarchy:

{% highlight cpp %}
class Base {
public:
    virtual ~Base() {}
};
{% endhighlight %}

{% highlight cpp %}
class A : public Base {
public:
    virtual ~A() {}
};
{% endhighlight %}

{% highlight cpp %}
class B : public Base {
public:
    virtual ~B() {}
};
{% endhighlight %}

{% highlight cpp %}
class C {
public:
    virtual ~C() {}
};
{% endhighlight %}

We match on the type:

{% highlight cpp %}
    Match<void>()
        .on<Base>([] (Base*) -> void { std::cout << "This was another kind of Base." << std::endl; })
        .on<A>([] (A*) -> void { std::cout << "This was an A." << std::endl; })
        .on<B>([] (B*) -> void { std::cout << "This was a B." << std::endl; })
        .on<C>([] (C*) -> void { std::cout << "This was a C." << std::endl; })
        .match(a);
{% endhighlight %}

Some notes
==========

* Types will be checked in reverse order, and the expression will exit as soon as a type is matched. If `Base` was after `A` and `B` in the expression, it would be matched first, and the others would never be tested.
* The final expression is evaluated by the invocation of the `match()` function, which accepts the pointer to the class being matched.
* Since `match()` is a template function, a single expression can actually match pointers in completely disjoint class hierarchies. This is shown with the `C` case above.

Future work
===========

* Someone more skilled than I may be able to adapt this to work with any type. For the sake of brevity and time, I only built this to work with pointers.
* This should be analyzed more closely to make sure there are no unnecessary copies of closures. `MatchCase` should 
be able to be move-only.