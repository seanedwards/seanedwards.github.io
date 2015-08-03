---
title: "More C++11: Context Stacks"
---

In today's post, more evil with C++ templates.

In the course of development of [Ides](http://ides-lang.com) I've repeatedly found that, in the highly recursive nature of code generation, I need a reliable way to keep track of context. For example, code generation within a function often needs to reference the actual function being generated, even though the compiler is deep inside an expression tree. There are several instances of this pattern appearing, and so I've made an attempt to generalize it into a variadic template class I've called `MultiContext`.

In a nutshell, `MultiContext` tracks multiple stacks of different heights and types alongside the call stack. If an item is placed into the `MultiContext` at some level `N` in the call stack, it will be popped when `N` returns or throws.

{% highlight cpp %}
    // The main case. T = the context type.
    template<typename... Args>
    class MultiContext : std::stack<Args>... {
        // MultiContextItem handles all stack operations for us, to ensure the stack stays sane.
        template<typename CT, typename CS>
        friend class MultiContextItem;
    public:
        template<typename A>
        A& Top() const { return ((std::stack<A>*)this)->top(); }
    protected:
        template<typename A> void Pop() { ((std::stack<A>*)this)->pop(); }
        template<typename A> void Push(A& t) { ((std::stack<A>*)this)->push(t); }
    };
{% endhighlight %}

Instances of a second class are created on the stack to ensure that items are always popped off the stack at the end of the proper scope:

{% highlight cpp %}
    template<typename T, typename S>
    class MultiContextItem {
    public:
        MultiContextItem(T& val, S& stack)
            : stack(stack), val(val)
        {
            stack.template Push<T>(this->val);
        }

        ~MultiContextItem() {
            // Sanity check.
            // We should be the only one with write access to the stack.
            // But evil exists.
            assert(stack.template Top<T>() == val);

            stack.template Pop<T>();
        }

    private:
        MultiContextItem( const MultiContextItem<T, S>& );
        const MultiContextItem<T, S>& operator=( const MultiContextItem<T, S>& );
        S& stack;
        T& val;
    };
{% endhighlight %}

For convenience, we define a macro that creates a MultiContextItem on the stack, assigned to a (hopefully) unique variable name, ensuring that items will be popped off the stack whether we return or throw an exception.

{% highlight cpp %}
#define SETCTX_OTHER(arg, self) MultiContextItem<decltype(arg), decltype(self)> __stack_ctx##arg(arg, self);
#define SETCTX(arg) SETCTX_OTHER(arg, *this)
{% endhighlight %}

The second macro references `this` under the assumption that `MultiContext` will be inherited by a visitor class doing the recursive processing.

Now we're able to support create multiple parallel stacks, bound to lexical scope.

Behold:

{% highlight cpp %}
int main() {
    int i = 5;
    int i2 = 10;
    std::string s = "test";
    MultiContext<int, double, std::string> ctx;
    {
        SETCTX_OTHER(i, ctx);
        SETCTX_OTHER(s, ctx);
        {
            SETCTX_OTHER(i2, ctx);
        }
        assert(ctx.Top<int>() == 5);
        assert(ctx.Top<std::string>() == "test");
    }
}
{% endhighlight %}
