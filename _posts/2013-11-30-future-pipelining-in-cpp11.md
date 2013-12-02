---
layout: default
title: "Future Pipelining in C++11"
comments: true
---

One nice feature of C++11 is [`std::future`](http://www.cplusplus.com/reference/future/future/). Unfortunately, in its current state, [pipelining](http://en.wikipedia.org/wiki/Futures_and_promises#Promise_pipelining) could be more convenient. Here's my idea for a solution, which I haven't used in anger, but seems to work very well.

A stream operator can be defined on futures and functions, which produces a new future:

{% highlight cpp %}
template<typename T, typename F>
auto operator<<(std::future<T> fut, const F& func) 
	-> std::future<decltype(func(fut.get()))>
{
    // Return a new future (deferred launch, 
    // similar to buffering on cout, avoids extraneous threads)
    return std::async(std::launch::deferred,
        [func] (std::future<T> fut) {
            return func(fut.get());
        }, std::move(fut));
}
{% endhighlight %}

<!--break-->

I will use these functions in the following examples:

{% highlight cpp %}
// Convert an int to a std::string.
std::string std::to_string( int value );

// Read (blocking) an int from stdin.
int read_int() {
    int ret;
    std::cin >> ret;
    return ret;
}

// Print a std::string to stdout.
int println(const std::string& str) {
    std::cout << str << std::endl;
    return 1;
    // We return an int just so we have 
    // a value to use in later examples.
}
{% endhighlight %}

By overloading the stream operator as I did above, pipelines can be defined in a single expression:

{% highlight cpp %}
int main() {
    std::async(read_int)
        << std::to_string
        << println; // Expression type is std::future<int>.

    return 0;
}
{% endhighlight %}

By adding a couple of extra overloads, we can direct the pipeline to either spin off in a detached background thread, or immediately block the current thread on the result:

{% highlight cpp %}
struct FutureGetter {};
FutureGetter get;

template<typename T>
auto operator<<(std::future<T> fut, const FutureGetter&) 
    -> decltype(fut.get())
{
    // Blocks the current thread on the previous future(s).
    return fut.get();
}
{% endhighlight %}

{% highlight cpp %}
struct FutureBackgrounder {};
FutureBackgrounder background;

template<typename T>
std::future<T>
operator<<(std::future<T> fut, const FutureBackgrounder&)
{
    // Spawns a detached thread that will execute the previous future(s).
    // Can't use std::async here, since std::future's destructure will block.
    // See: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3451.pdf
    std::shared_ptr<std::promise<T>> promise(new std::promise<T>()) ;
    std::thread([promise] (std::future<T> fut) {
        // Now the new thread blocks, rather than the caller.
        promise->set_value(fut.get());
    }, std::move(fut)).detach();
    return promise->get_future();
}
{% endhighlight %}


Now our pipeline can be spun off into the background:

{% highlight cpp %}
std::async(read_int)
    << std::to_string
    << println
    << background; // Expression is detached, type is std::future<int>.
{% endhighlight %}

Or we can block the current thread on the result:

{% highlight cpp %}
std::async(read_int)
    << std::to_string
    << println
    << get; // Expression will block, type is int.
{% endhighlight %}

It may also be useful to have an additional overload of `operator<<` to send the pipeline to a threadpool rather than an independent, detached thread.

You can view my full (and possibly updated) implementation [on GitHub](https://github.com/seanedwards/tinker/blob/master/cpp/future.cpp).
