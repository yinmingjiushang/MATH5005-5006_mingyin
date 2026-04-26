# Slide 3-11 视觉压缩与表达优化建议

评审对象：

- `latex/PPT/slides.pdf`
- `latex/PPT/sections/02_qr_brief.tex`
- `latex/PPT/sections/03_dnc_core.tex`
- `latex/PPT/sections/04_dnc_example.tex`
- `latex/PPT/script/live_script_15min.md`

目标：根据导师反馈，减少 slide 3-11 的阅读负担。这里的重点不是把长句机械缩短成短语，也不是把 slide 压到只剩关键词，而是达到中等程度的视觉压缩：版面有足够信息密度，观众能舒服地同时看文字、公式和图，并且能抓住每页的关键信息。

重要判断：下面的建议如果全部按“只保留 label + formula + visual”执行，会偏向极简演讲风格，可能让版面显得过空，也会让部分数学逻辑过度依赖口头解释。更合适的目标是每页保留：

- 1 个清楚标题；
- 1 组核心公式或核心图；
- 1 句简短 takeaway；
- 2-3 个短 bullet 或图中标注；
- 把完整推导和长解释移到讲稿或 backup。

另一个版式原则：数学原理部分尽量不用左右分栏。上下顺序更适合这组 slides，因为观众需要沿着“定义/操作 -> 公式结果 -> 为什么有用 -> 下一步问题”的逻辑往下读。左右分栏只适合矩阵图和示意图已经非常独立的页面；对于推导页，优先保持从上到下的因果链。

首行位置也应统一。Beamer 的普通 `frame` 默认会根据内容高度做垂直居中，内容少的页第一行会自然下沉，内容多的页第一行会靠上。因此主讲内容页建议使用 `\begin{frame}[t]{...}` 进行 top alignment；只有 title、Thank You、或者本身是满版图表且需要居中的页面例外。不要主要依靠逐页 `\vspace` 去修首行高度，否则后续改内容时很容易再次不一致。

## 总体原则

当前 slide 3-11 的主要问题不是数学不清楚，而是很多页同时承担了三件事：

1. 写出公式；
2. 用完整句解释公式；
3. 再说明算法意义。

这会让观众开始读 slide，而不是听讲。建议改成：

- slide 上保留：公式骨架、关键词、必要的一句解释、结构图、矩阵形状变化、颜色标记；
- 口头讲稿承担：为什么这样做、每个公式怎么读、和性能有什么关系；
- backup 承担：完整推导、条件说明、较长的数学解释。

可以采用一个简单判断标准：

- 观众 3 秒内能看懂的视觉结构，保留在 slide；
- 每页可以保留一句帮助理解的解释性 takeaway；
- 需要两句以上解释才能懂的文字，优先移到讲稿；
- 需要完整推导才成立的内容，放 backup。

## 推荐统一风格

### 1. Slide 上尽量使用 logical chain + formula + one takeaway

推荐格式：

```text
Shifted QR Iteration for Eigenvalue Computation
T_k = Q_k^T T_{k-1} Q_k
preserve spectrum
Takeaway: the iteration preserves eigenvalues while making the active block closer to diagonal, so the eigenvalues can be read from the limiting diagonal entries.
```

而不是：

```text
Thus one shifted QR step is an orthogonal similarity transformation...
```

也就是说，不建议压缩到只剩 `preserve spectrum` 这种孤立短语。更好的中等压缩是：上方给出操作，中间给出关键相似关系，下方用一句完整 takeaway 说明为什么这能求特征值。

### 2. 保留颜色，但让颜色只承担一种功能

现在颜色区分内容是好的，建议继续保留：

- `accent`：当前被操作的 bulge、coupling、deflation entry；
- `unswblue`：D&C、merged result、final eigenpair object；
- `steel/gray`：结构零、背景路径、非重点矩阵块。

不要在同一页让红色同时表示 warning、current step、important conclusion，否则观众需要重新学习颜色含义。

### 3. 每页只让观众记住一个动作

Slide 3-11 可以按动作设计：

- Slide 3：shifted QR preserves eigenvalues while moving toward diagonal form；
- Slide 4：first Givens creates a bulge；
- Slide 5：local rotations chase the bulge；
- Slide 6：repeat sweeps until deflation；
- Slide 7：D&C turns recursion into rank-one merges；
- Slide 8：split one coupling；
- Slide 9：solve children, change basis；
- Slide 10：secular roots give parent eigenvalues；
- Slide 11：recover and lift eigenvectors.

如果一页里出现两个以上动作，优先删文字或拆成图。

## Slide 3: Shifted QR Iteration for Eigenvalue Computation

当前问题：

- 文字解释偏 thesis style。
- 这页真正要讲的是 shifted QR 为什么能求特征值，而不仅是给出一个 algebraic step。
- 公式已经足够说明 similarity transformation，但还需要一句清楚解释把 `保谱`、`趋近对角`、`读出特征值` 串起来。
- 这页还要引出下一页 implicit QR，因此最后应自然落到：显式 QR factorization 太贵，实际用 Givens 进行 implicit implementation。

建议版面：

```text
Shifted QR Iteration for Eigenvalue Computation

T_{k-1} - mu_k I = Q_k R_k
-- reverse QR factors and shift back -->
T_k = mu_k I + R_k Q_k

=> T_k = Q_k^T T_{k-1} Q_k

orthogonal similarity: same eigenvalues
repeated shifts: active block approaches diagonal form
diagonal limit: eigenvalues appear on the diagonal

Next: implement this step implicitly with Givens rotations.
```

建议压缩或移入口头：

- `For the current active tridiagonal block, choose a shift...`
- `Reverse the factors and shift back...` 应保留意思，但压成公式箭头上的短 label，避免观众误以为 \(QR\to RQ\) 是普通代数变形。
- `Since R_k=...` 可以压缩成一行推导，不需要单独完整句。
- `Repeated shifted steps drive...` 不要删除，应改成短而有逻辑的一句 takeaway。

可视化建议：

- 不建议做左右分栏；这页应保持上下逻辑顺序。
- 把推导压成三组上下排列的公式，中间用 `\Downarrow` 或短 label 连接。
- 用一条因果链替代弱流程图：

```text
shifted QR step
      ↓
orthogonal similarity
      ↓
same eigenvalues, but entries change
      ↓
iteration drives subdiagonal entries small
      ↓
diagonal entries approximate eigenvalues
```

这条链比 `active block -> shifted QR -> similar block` 更适合本页，因为它直接回答“为什么能求特征值”。

这页不需要复杂图，但建议保留一句有完整逻辑的 takeaway，例如：

```text
Because each step is an orthogonal similarity transformation, the eigenvalues are unchanged; because the shifted iteration reduces the active subdiagonal entries, the limiting diagonal entries reveal those eigenvalues.
```

最后加一句过渡到下一页：

```text
In practice, we do not form the full QR factorization; we realize the same step implicitly with local Givens rotations.
```

## Slide 4: First Givens Rotation

当前优点：

- Givens matrix 和 bulge matrix 很适合作为上下连续的视觉解释。
- 颜色标出 first bulge 是有效的。

当前问题：

- 上方有较多完整句，观众会读文字而不是看矩阵图。
- 底部 legend 可以保留，但需要更短。

建议版面：

```text
First shifted column
x = (T - mu I)e_1

G_1 removes entry 2
G_1^T (T - mu I) G_1

first bulge
```

建议压缩或移入口头：

- `Only the first two entries are nonzero...`
- `Applying the same rotation from both sides preserves symmetry...`
- `Here x denotes...`

可视化建议：

- 将 `x=(T-\mu I)e_1` 保留为一个小公式。
- 把 Givens 2x2 rotation 和 bulge matrix 放大。
- 用箭头直接标注：

```text
annihilate
create bulge
```

底部 legend 可压缩为：

```text
x nonzero, . zero, + bulge
```

## Slide 5: Chase the Bulge

当前优点：

- 矩阵序列非常适合讲 bulge chasing。
- 这页是 QR 方法最应该视觉化的一页。

当前问题：

- 顶部公式和解释文字占据注意力。
- 矩阵序列本身已经能说明移动过程，文字可以减少到少量短 bullet。
- 现在公式、文字、矩阵序列三者都在解释同一件事。

建议版面：

```text
Bulge chasing sweep

G_i acts on rows/columns (i,i+1)

[bulge high] -> [bulge lower] -> ... -> [tridiagonal]
```

建议保留：

```tex
M_i = G_i^{\mathsf T} M_{i-1} G_i
```

建议压缩或移入口头：

- `After the first rotation, the sweep applies...`
- `Equivalently, ...`
- `At each step, the current bulge is removed...`
- `When the bulge reaches the block boundary...`

可视化建议：

- 保留三个或四个矩阵状态，并在每个状态下放 1-2 个短 label，让图和文字互相支撑。
- 在每个状态下方只写：

```text
create
chase
remove
```

或者：

```text
M_1
M_i
M_{m-1}
```

更进一步的图形替代：

- 用一条红色斜向下的 arrow path 表示 bulge 移动；
- 矩阵只画 band structure，不必每格都写 `x` 和 `.`；
- 当前 bulge 用红色方块，高亮位置随状态下移。

这样观众会先看到“bulge 被一路赶到底部”，而不是先读公式。

## Slide 6: Next Iterate and Deflation

当前问题：

- 同一页讲了 implicit Q theorem、local construction、eigenvector accumulation、deflation、repeat loop。
- 信息量过大，属于 slide 3-11 中最需要压缩的页之一。

建议改成流程图，而不是段落式解释。

推荐版面：

```text
One QR sweep

bulge chase
   -> T_k = Q_k^T T_{k-1} Q_k
   -> Z_k = Z_{k-1} Q_k
   -> deflation test

small subdiagonal?
yes: split block
no: choose next shift
```

建议保留公式：

```tex
Q_k = G_1G_2\cdots G_{m-1}
```

```tex
T_k = Q_k^{\mathsf T}T_{k-1}Q_k
```

```tex
Z_k = Z_{k-1}Q_k
```

建议压缩或移入口头：

- `Implicit Q theorem: first shifted column...`
- `No full QR factorization is formed...`
- `A sweep usually does not extract an eigenvalue immediately...`
- `Otherwise choose a new shift and repeat...`
- `Repeated similar iterates drive...`

可视化建议：

- 当前 deflation matrix 图很好，建议保留，但不要再配长解释。
- 可以把 deflation 改成更明显的 block split 图：

```text
T active
   small b_i -> 0
T_1 | T_2
```

如果页面仍然拥挤，建议把 implicit Q theorem 只放 backup，主 slide 用口头一句带过：

> The implicit Q theorem is why this local bulge chase represents the shifted QR step.

## Slide 7: D&C Why the Recursion Works

当前问题：

- 这页是 D&C 的概念总览，但文字和公式都较多。
- 它和后面 slide 8-11 内容有重复：rank-one split、child solve、secular merge、upward recursion 后面都会讲。

建议改成 split-merge tree 图，而不是证明式文字。

推荐版面：

```text
Divide-and-conquer idea

split T
solve children
merge by D + rho z z^T
repeat upward
```

可视化建议：

画一棵小树：

```text
        T
      /   \
    T1     T2
   / \     / \
 leaves  leaves

 upward merge: D + rho z z^T
```

树图下方保留一个关键公式，再配一句 takeaway：

```tex
Q_0^{\mathsf T}T_{\mathrm{parent}}Q_0
= D+\rho zz^{\mathsf T}
```

```text
Takeaway: solve small children, then merge upward.
```

建议压缩或移入口头：

- `The recursion is justified by induction on the split tree.`
- `At each parent node, the split is exact after compensation...`
- `If the child eigenproblems are solved...`
- `The secular merge solves...`

注意：如果后面 slide 8-11 已经详细讲 D&C 步骤，这页可以更像“地图页”，不要重复代数。

## Slide 8: Split and Isolate One Coupling

当前优点：

- 矩阵图高亮 \(b_3\) 很好，应该保留。
- 这页适合用图说明“切开一个 coupling”。

当前问题：

- 当前 slide 同时做了 step 1 和 coupling compensation，内容偏满。
- 文字解释 `T_1,T_2 are not simply raw principal blocks` 很重要，但不一定要完整写在 slide 上。

建议版面：

上方：大矩阵图，高亮 \(b_3\)，显示 cut line。

下方：保留 rank-one rewrite，并加一句说明“不丢掉 coupling，而是延后到 merge”。

```tex
\rho=|b_3|,
\qquad
u=e_3+\sigma e_4
```

```tex
T=
\begin{bmatrix}
T_1&0\\
0&T_2
\end{bmatrix}
+\rho uu^{\mathsf T}
```

建议压缩或移入口头：

- `Choose one middle coupling...`
- `With b_3=... the local interface split is...`
- `The diagonal shifts are absorbed...`
- `The rank-one term carries...`

可视化建议：

- 用颜色把矩阵分成三类：
  - 左 child block；
  - 右 child block；
  - interface coupling；
- 在高亮 coupling 旁边写短 label：

```text
defer coupling
```

不建议再额外放 2x2 local interface 推导在主 slide。这个推导适合 backup，主 slide 只需要观众记住：切开以后不是丢掉 \(b_3\)，而是把它变成 rank-one correction。

## Slide 9: Solve the Two Children First

当前问题：

- 这页公式较多，解释句也较多。
- 观众需要同时理解 child eigendecomposition、block diagonal basis、coupling vector transform、diagonal-plus-rank-one parent problem。

建议改成 basis-change 流程图。

推荐版面：

```text
children solved

T_1 = Q_1 D_1 Q_1^T
T_2 = Q_2 D_2 Q_2^T

Q_0 = blkdiag(Q_1,Q_2)

parent basis:
D + rho z z^T
```

可视化建议：

用三格图：

```text
child blocks
    -> child eigenbasis
    -> diagonal + rank-one
```

或者：

```text
[T1  0]       [D1  0]
[0  T2]  ->   [0  D2]  + rho z z^T
```

建议保留公式：

```tex
Q_0=\operatorname{blkdiag}(Q_1,Q_2),
\qquad
D=D_1\oplus D_2
```

```tex
Q_0^{\mathsf T}TQ_0 = D+\rho zz^{\mathsf T}
```

建议压缩或移入口头：

- `Recursion continues until...`
- `Here Q_1,Q_2 are orthogonal...`
- `Combine them into...`
- `Thus z stores...`
- `This diagonal-plus-rank-one problem is...`

如果需要解释 \(z\)，slide 上只写：

```text
z = boundary components in child eigenbasis
```

完整公式可以留给口头或 backup。

## Slide 10: Merge the Parent Block

当前优点：

- secular function plot 是非常好的 slide 内容。
- 这页已经比其他页更视觉化，应该保留图。

当前问题：

- 说明文字仍然偏多。
- interlacing 公式和 root bracket 公式有重复，可以只留一个。

建议版面：

上方保留核心 secular equation：

```tex
f(\lambda)
=1+\rho\sum_i \frac{z_i^2}{d_i-\lambda}=0
```

中间放大 secular plot。

图下方保留三条极短 label：

```text
d_i: child eigenvalues / poles
lambda_i: parent eigenvalues / roots
one root per interval
```

建议压缩或移入口头：

- `(D+\rho zz^T)y=\lambda y` 可移入口头或 backup；
- `After sorting the active poles...`；
- `Interlacing gives one bracket...`；
- `The merge is scalar root-finding...`。

可视化建议：

- 把图里的 dashed poles 和 zero crossings 标得更大；
- 如果空间允许，在 x-axis 上方直接标：

```text
poles d_i
roots lambda_i
```

这样观众不需要读很长的说明段落，也能理解图。

## Slide 11: Recover the Eigenvectors

当前问题：

- 这页有多组公式，观众容易陷入读公式。
- 这页的核心其实是 two-step eigenvector recovery：先在 diagonal basis 得到 \(Y\)，再乘 \(Q_0\) lift back。

建议改成两层 basis 图。

推荐版面：

```text
Eigenvectors after roots

diagonal basis:
y_j ∝ (D - lambda_j I)^{-1} z

parent basis:
Q_parent = Q_0 Y
```

可视化建议：

```text
roots lambda_j
     ↓
Y in diagonal basis
     ↓ multiply Q_0
Q_parent in original parent block
```

或用上下两层：

```text
Diagonal basis
y_j ∝ (D-lambda_j I)^{-1}z
      ↓
Parent basis
Q_parent = Q_0Y
```

建议保留公式：

```tex
(\widehat y_j)_i=\frac{z_i}{d_i-\lambda_j}
```

```tex
Q_{\mathrm{parent}}=Q_0Y
```

建议压缩或移入口头：

- `After Step 4, the roots...`
- `Normalize these vectors and collect them...`
- `The matrix Y is still...`
- `The current parent block is complete...`

最后一句可压成：

```text
pass parent eigenpairs upward
```

## 建议优先级

### 高优先级

1. Slide 6 改成 QR sweep/deflation flowchart，删除 theorem-level 长解释。
2. Slide 7 改成 D&C split-merge tree，不再写 induction-style explanation。
3. Slide 8 压缩 2x2 local split 推导，主 slide 以 matrix cut + rank-one rewrite 为主，再保留一句解释 coupling 没有丢失。
4. Slide 11 改成 basis-lift 图，突出 \(Y \to Q_0Y\)。

### 中优先级

1. Slide 5 放大 bulge-chasing 图，减少顶部公式和说明。
2. Slide 9 改成 child-basis transformation 图。
3. Slide 10 放大 secular plot，说明文字压缩为图下 label。

### 低优先级

1. Slide 3 保留三行 QR 公式，加一句 similarity takeaway，不需要完整推导文字。
2. Slide 4 保留 Givens rotation 和 bulge matrix，压缩上下说明。

## 可以直接采用的短标题

当前一些标题偏长，可以考虑改短：

| 当前标题 | 建议标题 |
| --- | --- |
| `Explicit Shifted QR: The Algebraic Step` | `Shifted QR Iteration for Eigenvalue Computation` |
| `Implicit Shifted QR, Step 1: First Givens Rotation` | `First Givens: Create a Bulge` |
| `Implicit Shifted QR, Step 2: Chase the Bulge` | `Chase the Bulge` |
| `Implicit Shifted QR, Step 3: Next Iterate and Deflation` | `Repeat Until Deflation` |
| `Divide-and-Conquer: Why the Recursion Works` | `D&C Split-Merge Structure` |
| `Divide-and-Conquer, Step 1: Split and Isolate One Coupling` | `Split One Coupling` |
| `Divide-and-Conquer, Step 3: Solve the Two Children First` | `Solve Children First` |
| `Divide-and-Conquer, Step 4: Merge the Parent Block` | `Secular Merge` |
| `Divide-and-Conquer, Step 5: Recover the Eigenvectors` | `Recover Eigenvectors` |

## 文字压缩示例

这些不是唯一写法，重点是 slide 上只放提示词，完整解释留给讲稿。

| 原 slide 风格 | 建议 slide 风格 |
| --- | --- |
| `Thus one shifted QR step is an orthogonal similarity transformation` | `orthogonal similarity` |
| `Repeated shifted steps drive the active block toward diagonal form` | `repeat -> diagonal` |
| `Applying the same rotation from both sides preserves symmetry, but creates one off-tridiagonal entry` | `preserve symmetry; create bulge` |
| `The recursion is justified by induction on the split tree` | `split tree + upward merges` |
| `The diagonal shifts are absorbed into the two compensated child blocks` | `compensated child blocks` |
| `The merge is scalar root-finding, not another matrix sweep` | `scalar root-finding` |
| `The matrix Y is still in the child eigenvector basis, so transform back` | `lift back: Q_parent = Q_0Y` |

## 最终建议

Slide 3-11 最适合的修改方向是：

- QR 部分多用矩阵结构图和流程图，让观众看到 bulge 如何产生、移动、消失；
- D&C 部分多用 split tree、block matrix、basis transformation 图，让观众看到问题如何被拆开再合并；
- 公式保留核心结果，不保留完整推导；
- 长解释性完整句尽量转移到 `live_script_15min.md`，但每页保留一句帮助观众理解的 takeaway。

如果时间有限，优先改 slide 6-8 和 slide 11。这几页目前最像 thesis 页面，压缩后整套 presentation 的阅读负担会明显下降。
