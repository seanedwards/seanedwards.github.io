---
layout: default
title: "Why am I using swap space when I have plenty of RAM?"
subtitle: "And what the heck is 'swappiness' anyway?"
comments: true
---

Most savvy computer users are at least vaguely familiar with the concept of swap space, or the Windows page file. Here's some disorganized, high-level information on Linux swap space.

The kernel can send memory to swap even when it doesn't have to. The knob for controlling how likely it is to do this is called *swappiness* and it ranges from 0 to 100. On many systems, the default is set to 60. If set to 0, the kernel will only swap out pages to avoid actually running out of physical memory. If you set swappiness to 0, you should probably have lots of ram and a pretty good reason. Having RAM headroom is usually a good thing. Nobody wants to block their memory allocations on disk writes.

Having memory pages in swap isn't necessarily bad. Sure, they'll take longer to access if they're needed, but computers are complex, and at any given time there is plenty of data in memory that just isn't needed in a normal running system. Kernel code for drivers that aren't needed by any of the hardware attached to that system probably don't need to be taking up comparatively valuable RAM space.

What you might want to look out for, however, is swap thrashing. That happens when, for one reason or another, the kernel keeps sending memory to swap to and from swap. I would expect this to happen most often when the system doesn't have quite enough physical RAM for the workload, but I'm sure there are plenty of other ways to induce that behavior.

You can use `vmstat` to monitor swap activity. As always, consult your local man pages for detailed usage. My favorite incantation is:
{% highlight bash %}
vmstat \ # Probably already installed on your system
  -w \   # Make the columns wider, to accomidate lots of digits of RAM.
  1      # And poll every second
{% endhighlight %}

Pay partiuclar attention to the `si` (swap in) and `so` (swap out) columns. Those columns indicate the number of bytes that were swapped during that polling interval.

The performance impact of swapping is dependent on a lot of factors, so without controlling for any of those, the only definitive guideline for whether swapping is hurting performance is to say that if `si` and `so` are flat zero, swapping is probably not the problem.

Otherwise, if it's not zero, you're swapping, and if it's extremely not zero, you're swapping even more than that. SSD-backed swap space will make swapping faster. Magnetic-backed network swap space will probably make swapping very painful. Keep your disk close, and your swap closer.

If I'm wrong about any of this stuff, please leave me a constructive comment so I can fix the problem.

