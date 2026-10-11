# LaTeX Mathematical Specifications

## 1. Delimiter Formats
- Dollar inline: $E = mc^2$
- Escaped parenthesis inline: \( \nabla \times \vec{B} = \mu_0 \vec{J} + \mu_0 \varepsilon_0 \frac{\partial \vec{E}}{\partial t} \)
- Dollar display:
$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$
- Escaped bracket display:
\[
\sum_{k=1}^{n} k^3 = \left( \frac{n(n+1)}{2} \right)^2
\]

## 2. Advanced Environments
$$
\begin{pmatrix}
a & b \\
c & d
\end{pmatrix}^{-1} = \frac{1}{ad-bc}
\begin{pmatrix}
d & -b \\
-c & a
\end{pmatrix}
$$

Aligned system:
$$
\begin{aligned}
x + y + z &= 6 \\
2y + 5z &= -4 \\
2x + 5y - z &= 27
\end{aligned}
$$

Chemistry:
\ce{CH4 + 2O2 -> CO2 + 2H2O}

