/-
Copyright (c) 2019 mathlib community. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Wojciech Nawrocki
-/
import data.rbtree.init
import data.num.basic

/-!
# Binary tree

Provides binary tree storage for values of any type, with O(lg n) retrieval.
See also `data.rbtree` for red-black trees - this version allows more operations
to be defined and is better suited for in-kernel computation.

## References

<https://leanprover-community.github.io/archive/stream/113488-general/topic/tactic.20question.html>
-/

/-- A binary tree with values stored in non-leaf nodes. -/
@[derive has_reflect, derive decidable_eq]
inductive {u} tree (α : Type u) : Type u
| nil : tree
| node : α → tree → tree → tree

namespace tree

universe u
variable {α : Type u}

/-- Construct a string representation of a tree. Provides a `has_repr` instance. -/
def repr [has_repr α] : tree α → string
| nil := "nil"
| (node a t1 t2) := "tree.node " ++ has_repr.repr a
                    ++ " (" ++ repr t1 ++ ") (" ++ repr t2 ++ ")"

instance [has_repr α] : has_repr (tree α) := ⟨tree.repr⟩

instance : inhabited (tree α) := ⟨nil⟩

/-- Makes a `tree α` out of a red-black tree. -/
def of_rbnode : rbnode α → tree α
| rbnode.leaf               := nil
| (rbnode.red_node l a r)   := node a (of_rbnode l) (of_rbnode r)
| (rbnode.black_node l a r) := node a (of_rbnode l) (of_rbnode r)

/-- Finds the index of an element in the tree assuming the tree has been
constructed according to the provided decidable order on its elements.
If it hasn't, the result will be incorrect. If it has, but the element
is not in the tree, returns none. -/
def index_of (lt : α → α → Prop) [decidable_rel lt]
  (x : α) : tree α → option pos_num
| nil := none
| (node a t₁ t₂) :=
  match cmp_using lt x a with
  | ordering.lt := pos_num.bit0 <$> index_of t₁
  | ordering.eq := some pos_num.one
  | ordering.gt := pos_num.bit1 <$> index_of t₂
  end

/-- Retrieves an element uniquely determined by a `pos_num` from the tree,
taking the following path to get to the element:
- `bit0` - go to left child
- `bit1` - go to right child
- `pos_num.one` - retrieve from here -/
def get : pos_num → tree α → option α
| _                nil            := none
| pos_num.one      (node a t₁ t₂) := some a
| (pos_num.bit0 n) (node a t₁ t₂) := t₁.get n
| (pos_num.bit1 n) (node a t₁ t₂) := t₂.get n

/-- Retrieves an element from the tree, or the provided default value
if the index is invalid. See `tree.get`. -/
def get_or_else (n : pos_num) (t : tree α) (v : α) : α :=
  (t.get n).get_or_else v

/-- Apply a function to each value in the tree.  This is the `map` function for the `tree` functor.
TODO: implement `traversable tree`. -/
def map {β} (f : α → β) : tree α → tree β
| nil := nil
| (node a l r) := node (f a) (map l) (map r)

/-- The number of nodes (including leaves) of a binary tree -/
@[simp] def nodes : tree α → ℕ
| nil := 1
| (node _ a b) := a.nodes + b.nodes + 1

/-- The number of leaves of a binary tree -/
@[simp] def leaves : tree α → ℕ
| nil := 1
| (node _ a b) := a.leaves + b.leaves

lemma leaves_pos (x : tree α) : 0 < x.leaves :=
by { induction x, { exact nat.zero_lt_one, }, apply nat.lt_add_left, assumption, }

/-- A non-nil ptree; useful when we want an arbitrary value other than `nil` -/
abbreviation non_nil [inhabited α] : tree α := node default nil nil

@[simp] lemma non_nil_ne [inhabited α] : non_nil ≠ (@nil α) := by trivial

/-- The left child of the tree, or `nil` if the tree is `nil` -/
@[simp] def left : tree α → tree α
| nil := nil
| (node _ l r) := l

/-- The right child of the tree, or `nil` if the tree is `nil` -/
@[simp] def right : tree α → tree α
| nil := nil
| (node _ l r) := r

end tree
