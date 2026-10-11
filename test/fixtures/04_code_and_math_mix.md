# Code Blocks and Math Interleaving

## Code Block with Math Delimiters
Here is a Python code example where strings look like LaTeX:

```python
equation = "$E = mc^2$"
display_formula = r"\[ \int_0^1 x dx \]"
pattern = r"\((.*?)\)"
print(equation, display_formula)
```

And in bash with tildes:

~~~bash
#!/usr/bin/env bash
VAR="\(literal parenthesized text\)"
echo "$VAR"
~~~

Prose math right below: \( \alpha + \beta = \gamma \).
Inline code containing math: `\(not_an_equation\)` and `$$literal$$`.
Real equation: $f(x) = x^2$.

