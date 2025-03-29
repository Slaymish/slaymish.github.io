2025-03-29

***

So I watched this video on a new research paper from meta ([@geiping2025scaling]). I'll lead in with what common reasoning models do first, then I'll discuss how this seems to be a massive improvement in my mind. Currently, the SoTa reasoning models (o3-mini, deepseek R3, gemini 3.5 pro) have the same architecture in common. Essentially they are still just a regular Large Language Model, that has been fine-tuned to instead of directly giving a response to a query, they reason or 'think' for some time. This is done by outputting tokens, and most of them are trained to use their previous reasoning for that query in the next tokens context, which allows them to catch mistakes they made, and check their work. 

This has a great number of benefits, as for starters, no real change to the underlying architecture is required. It's still functions in the same way any existing LLM would, its just trained to 'reason' for a bit with their output tokens. This means essentially any LLM came 'become' a reasoning model. For example, AutoGPT, one of the first open source chain of thought projects did this. Though instead of directly training the model to reason, the directive to reason would just be given in the initial prompt. So you'd give it the goal you'd like it to achieve, it'd continually call itself and use its own previous context to work towards the goal. 

Anyway… Meta's new paper, "Scaling up Test-Time Compute with Latent Reasoning:
A Recurrent Depth Approach", takes an entirely different approach. Instead of relegating the reasoning to occur in the output tokens, the model implicitly reasons in latent space. This means that, it doesn't reason in 'word' (or tokens), but still inside of the blackbox of the model. This gives a number of benefits over the common token reasoning  models. 

For starters, reasoning by outputting to tokens first is naturally lossy. You are selecting the highest probability next token, meaning all the information that was inside of that last probability distribution is lost. I'll give an example of what I mean:

Say the input is:

$$\text{Whats the meaning of life?}$$

*note: this is obviously not exactly how it works, as there'd be a number of tokens as a precursor to the 'answer', though the point is the same for all those tokens as well*

An LLM would provide a probability distribution akin to the following:

$$\{\text{"42"}:0.1,\text{"friends"},0.25,\text{"love"},0.45,\text{"nothing"},0.2\}$$

A token reasoning model would then, as their next step in reasoning, choose the next token with the highest probability:


$$\text{The meaning of life is: love}$$

Wait, but what happened to all the other options?!

A *latent* reasoning model would use the entire probability distribution as input for the next reasoning step. So:


$$\text{The meaning of life is:} \ \{\text{"42"}:0.1,\text{"friends"},0.25,\text{"love"},0.45,\text{"nothing"},0.2\}$$


This is the benefit of the **high dimensionality of latent space**. You can persist all possible options of an answer, throughout the reasoning process. This allows for much more complex reasoning, and shows how converting it to *language is inherently 'lossy'* (as you literally 'lose' all the other possible options!).